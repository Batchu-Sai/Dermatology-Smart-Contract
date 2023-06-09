pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

contract Dermatology_IPFS {


////////////// INITIALIZE MAPPINGS AND ARRAYS

      // mappings to hold data values and and corresponding arrays for their keys
      mapping (bytes32 => uint[]) ALDEN_scores; //key = ALDEN_score
      mapping (bytes32 => uint[]) patientIDs; //key = patientID
      mapping (string => uint[]) BSA_involved_maximums; //key = BSA_involved_maximum

      mapping (uint => PatientDataStruct) database;
      // counter to assign each entry a unique index
      uint counter;
      // array to hold the unique ALDEN_score-patientIDNumber-BSA_involved_maximum entries
      UniqueObservations[] uniqueObservationsArray;


///////////////// DEFINE STRUCTS

    // Struct format to return data from query function.
    struct ObservationReturnStruct {
        string ALDEN_score;
        uint SCORTEN_predicted_mortality;
        uint patientID;
        uint BSA_involved_at_admission;
        string BSA_involved_maximum;
        bytes32 ipfsHash;
        //uint totalCount;
    }
    // struct to hold the data in database
    struct PatientDataStruct {
        bytes32 ALDEN_scoreField;
        bytes32 SCORTEN_predicted_mortalityField;
        bytes32 patientIDField;
        bytes32 BSA_involved_at_admissionField;
        string BSA_involved_maximumField;
        bytes32 ipfsHashField;
        uint index;
        address whoAdded;
    }
    // struct to hold unique ALDEN_score-patientID-BSA_involved_maximum
    struct UniqueObservations {
    	bytes32 disease;
    	bytes32 patientID;
    	string BSA_involved_maximum;
    }
    // struct to check which fields were queried
    struct FieldQueries {
        bool ALDEN_score;
        bool patientIDNumber;
        bool BSA_involved_max;
    }


//////////////////// INSERT and QUERY FUNCTIONS

    //  Inserts observation. No return value.
    function insertRecord (
        string memory disease,
        uint SCORTEN_predicted_mortality,
        uint patientID,
        uint BSA_involved_at_admission,
        string memory ALDEN_score,
        bytes32 ipfsHash
    ) public {
        bytes32 name = stringToBytes32(disease);
        bytes32 grading = stringToBytes32(intToString(SCORTEN_predicted_mortality));
        bytes32 patientIDNumber = stringToBytes32(intToString(patientID));
        bytes32 BSA_involved_at_admission_score = stringToBytes32(intToString(BSA_involved_at_admission));
        bytes32 IPFS_hash = ipfsHash;
        address who = msg.sender;

        // check if the ALDEN_score-patientIDNumber-BSA_involved_max combo already exists in the database. If not, add it to the uniqueObservationsArray
        if (observationExists(disease, intToString(patientID), ALDEN_score) == false) {
            uniqueObservationsArray.push(UniqueObservations(name, patientIDNumber, ALDEN_score));
        }
        // update the four mappings
        diseases[name].push(counter);
        patientIDs[patientIDNumber].push(counter);
        ALDEN_scores[ALDEN_score].push(counter);
        database[counter] = PatientDataStruct(name, grading, patientIDNumber, BSA_involved_at_admission_score, ALDEN_score, IPFS_hash, counter, who);
        // update global counter/index
        counter++;
    }


// Takes BSA_max, patientIDNumber, and ALDEN_score as strings. Asterisk "*" fconsidered as wildcard. Returns array of ObservationReturnStruct Structs which match the query parameters.
 function retrieveRecord(
        string memory disease,
        string memory patientID,
        string memory ALDEN_score
    ) public view returns (ObservationReturnStruct[] memory) {
        // initialize memory structs and variables
        uint numFields;
        FieldQueries memory queryInfo;
        ObservationReturnStruct[] memory empty;
        uint[] memory BSA_involved_maxSearch;
        uint[] memory patientIDSearch;
        uint[] memory ALDEN_scoreSearch;
        uint[] memory indexSearch = new uint[](counter);
        UniqueObservations[] memory uniqueSearch = new UniqueObservations[](uniqueObservationsArray.length);

        // if database is empty, return empty array
        if (counter == 0) {
            return empty;
        }
        // count the number of fields used to search
        if (compareStrings(disease, "*") == false) { // if disease field was not "*", increase numFields & mark disease true in queryInfo struct
            diseaseSearch = diseases[stringToBytes32(disease)];
            numFields++;
            queryInfo.cancer = true;
        }
        if (compareStrings(patientID, "*") == false) { // if patientID field was not "*", increase numFields & mark patientID true in queryInfo struct
            patientIDSearch = patientIDs[stringToBytes32(patientID)];
            numFields++;
            queryInfo.patientIDNumber = true;
        }
        if (compareStrings(drug, "*") == false) { // if drug field was not "*", increase numFields & mark drug true in queryInfo struct
            DrugNameSearch = DrugNames[drug];
            numFields++;
            queryInfo.drug = true;
        }

        uint matchCount; // num entries in the database that matched the query
        uint uniqueCount; // num unique cancer-patientIDNumber-drug combos in the query results

        if ((compareStrings(disease, "*") == true) &&
            (compareStrings(patientID, "*") == true) &&
            (compareStrings(drug, "*") == true)
            ) {
            matchCount = counter;
            uniqueCount = uniqueObservationsArray.length;
            uniqueSearch = uniqueObservationsArray;
            for (uint i; i < counter; i++) {
                indexSearch[i] = i;
            }
        } else {
            uint min = counter;
            uint which_one = 3;
            if (diseaseSearch.length <= min && diseaseSearch.length != 0){
                min = diseaseSearch.length;
                which_one = 0;
            }
            if (patientIDSearch.length <= min && patientIDSearch.length != 0){
                min = patientIDSearch.length;
                which_one = 1;
            }
            if (DrugNameSearch.length <= min && DrugNameSearch.length != 0){
                min = DrugNameSearch.length;
                which_one = 2;
            }
            if (diseaseSearch.length == patientIDSearch.length && patientIDSearch.length == DrugNameSearch.length) {
                min = diseaseSearch.length;
                which_one = 0;
            }

            for (uint i; i < min; i++) {
                uint found = 1;
                //if shortest array is diseasesearch
                if (which_one == 0) {
                    if (queryInfo.patientIDNumber == true) {
                        for (uint j; j < patientIDSearch.length; j++){
                            if (diseaseSearch[i] == patientIDSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (queryInfo.drug == true) {
                        for (uint j; j < DrugNameSearch.length; j++){
                            if (diseaseSearch[i] == DrugNameSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (found == numFields){
                        indexSearch[matchCount] = diseaseSearch[i];
                        matchCount++;
                        PatientDataStruct memory addMe = database[diseaseSearch[i]];
                        if (observationExistsUnique(addMe.diseaseField, addMe.patientIDField, addMe.DrugNameField, uniqueSearch) == false) {
                            uniqueSearch[uniqueCount] = UniqueObservations(addMe.diseaseField, addMe.patientIDField, addMe.DrugNameField);
                            uniqueCount++;
                        }
                    }
                }
                //if shortest array patientIDsearch
                if (which_one == 1){
                    if (queryInfo.cancer == true) {
                        for (uint j; j < diseaseSearch.length; j++){
                            if (patientIDSearch[i] == diseaseSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (queryInfo.drug == true) {
                        for (uint j; j < DrugNameSearch.length; j++){
                            if (patientIDSearch[i] == DrugNameSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (found == numFields){
                        indexSearch[matchCount] = patientIDSearch[i];
                        matchCount++;
                        PatientDataStruct memory addMe = database[patientIDSearch[i]];
                        if (observationExistsUnique(addMe.diseaseField, addMe.patientIDField, addMe.DrugNameField, uniqueSearch) == false) {
                            uniqueSearch[uniqueCount] = UniqueObservations(addMe.diseaseField, addMe.patientIDField, addMe.DrugNameField);
                            uniqueCount++;
                        }
                    }
                }
                //if shortest array is DrugNamesearch
                if (which_one == 2){
                    if (queryInfo.patientIDNumber == true) {
                        for (uint j; j < patientIDSearch.length; j++){
                            if (DrugNameSearch[i] == patientIDSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (queryInfo.cancer == true) {
                        for (uint j; j < diseaseSearch.length; j++){
                            if (DrugNameSearch[i] == diseaseSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (found == numFields){
                        indexSearch[matchCount] = DrugNameSearch[i];
                        matchCount++;
                        PatientDataStruct memory addMe = database[DrugNameSearch[i]];
                        if (observationExistsUnique(addMe.diseaseField, addMe.patientIDField, addMe.DrugNameField, uniqueSearch) == false) {
                            uniqueSearch[uniqueCount] = UniqueObservations(addMe.diseaseField, addMe.patientIDField, addMe.DrugNameField);
                            uniqueCount++;
                        }
                    }
                }
            }
        }

        //trim arrays to increase looping efficiency
        uint[] memory trimIndexSearch = new uint[](matchCount);
        UniqueObservations[] memory trimUniqueSearch = new UniqueObservations[](uniqueCount);
        for (uint i; i < matchCount; i++) {
            trimIndexSearch[i] = indexSearch[i];
        }
        for (uint j; j < uniqueCount; j++) {
            trimUniqueSearch[j] = uniqueSearch[j];
        }

        // build final struct from search results
        ObservationReturnStruct[] memory matches = new ObservationReturnStruct[](uniqueCount); // final struct array
        uint tally; // num entries for a given cancer-patientIDNumber-drug combo
        for (uint a; a < trimUniqueSearch.length; a++){
            uint[] memory sameThing = new uint[](counter);
            tally = 0;
            for (uint b; b < matchCount; b++) {
                 // number of matches per unique combo
                if ((trimUniqueSearch[a].disease == database[trimIndexSearch[b]].diseaseField) &&
                    (trimUniqueSearch[a].patientID == database[trimIndexSearch[b]].patientIDField) &&
                    compareStrings(trimUniqueSearch[a].DrugName, database[trimIndexSearch[b]].DrugNameField)
                    ) {
                    sameThing[tally] = trimIndexSearch[b]; // add search result to sameThing if it matches uniqueSearch a
                    tally++;
                }
            }

            matches[a].disease = bytes32toString(database[sameThing[0]].diseaseField);
            matches[a].patientID = stringToInt(bytes32toString(database[sameThing[0]].patientIDField));
            matches[a].BSA_involved_at_admission = stringToInt(bytes32toString(database[sameThing[0]].BSA_involved_at_admissionField));
            matches[a].DrugName = database[sameThing[0]].DrugNameField;
            matches[a].ipfsHash = (database[sameThing[0]].ipfsHashField);
            matches[a].SCORTEN_predicted_mortality = stringToInt(bytes32toString(database[sameThing[0]].SCORTEN_predicted_mortalityField));
        }
        return matches; // final struct array of cancerDrugpatientID structs
    }

//////////////////// AUXILIARY UTILITIES

// Checks if observation already exists and returns boolean value. If wild card is used, then true if any relation exists that passes the non-wildcard criteria.
   function observationExists(
        string memory disease,
        string memory patientID,
        string memory drug
    ) public view returns (bool){
         // initialize memory structs and variables
        uint numFields;
        uint[] memory diseaseSearch;
        uint[] memory patientIDSearch;
        uint[] memory DrugNameSearch;

        FieldQueries memory queryInfo;
        // if database is empty, return empty array
        if (counter == 0) {
            return false;
        }

        // count the number of fields used to search
        if (compareStrings(disease, "*") == false) {
            numFields++;
            queryInfo.cancer = true;
            diseaseSearch = diseases[stringToBytes32(disease)];
        }
        if (compareStrings(patientID, "*") == false) {
            numFields++;
            queryInfo.patientIDNumber = true;
            patientIDSearch = patientIDs[stringToBytes32(patientID)];
        }
        if (compareStrings(drug, "*") == false) {
            numFields++;
            queryInfo.drug = true;
            DrugNameSearch = DrugNames[drug];
        }

        if ((compareStrings(disease, "*") == true) &&
            (compareStrings(patientID, "*") == true) &&
            (compareStrings(drug, "*") == true)
            ) {
            return true;

        } else {
            uint min = counter;
            uint which_one = 3;
            if (diseaseSearch.length <= min && diseaseSearch.length != 0){
                min = diseaseSearch.length;
                which_one = 0;
            }
            if (patientIDSearch.length <= min && patientIDSearch.length != 0){
                min = patientIDSearch.length;
                which_one = 1;
            }
            if (DrugNameSearch.length <= min && DrugNameSearch.length != 0){
                min = DrugNameSearch.length;
                which_one = 2;
            }
            if (diseaseSearch.length == patientIDSearch.length && patientIDSearch.length == DrugNameSearch.length) {
                min = diseaseSearch.length;
                which_one = 0;
            }
            uint found;
            for (uint i; i < min; i++) {
                found = 1;
                //if shortest array is diseasesearch
                if (which_one == 0) {
                    if (queryInfo.patientIDNumber == true) {
                        for (uint j; j < patientIDSearch.length; j++){
                            if (diseaseSearch[i] == patientIDSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (queryInfo.drug == true) {
                        for (uint j; j < DrugNameSearch.length; j++){
                            if (diseaseSearch[i] == DrugNameSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (found == numFields) {
                        break;
                    }
                }
                //if shortest array patientIDsearch
                if (which_one == 1){
                    if (queryInfo.cancer == true) {
                        for (uint j; j < diseaseSearch.length; j++){
                            if (patientIDSearch[i] == diseaseSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (queryInfo.drug == true) {
                        for (uint j; j < DrugNameSearch.length; j++){
                            if (patientIDSearch[i] == DrugNameSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (found == numFields){
                        break;
                    }
                }
                //if shortest array is DrugNamesearch
                if (which_one == 2){
                    if (queryInfo.patientIDNumber == true) {
                        for (uint j; j < patientIDSearch.length; j++){
                            if (DrugNameSearch[i] == patientIDSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (queryInfo.cancer == true) {
                        for (uint j; j < diseaseSearch.length; j++){
                            if (DrugNameSearch[i] == diseaseSearch[j]){
                                found++;
                                break;
                            }
                        }
                    }
                    if (found == numFields){
                        break;
                    }
                }
            }
            if (found == numFields){
                return true;
            }
            else{
                return false;
            }
        }
    }

// Checks if a cancer-patientIDNumber-drug combination already exists in a UniqueObservations[] array and returns boolean
    function observationExistsUnique (
        bytes32 disease,
        bytes32 patientID,
        string memory drug,
        UniqueObservations[] memory array) internal pure returns (bool){
        if (array.length == 0) {
            return false;
        }
        uint searcher;
        for (uint j; j < array.length; j++) {
            if (array[j].disease == disease && array[j].patientID == patientID && compareStrings(array[j].DrugName, drug) == true) {
                searcher++;
                break;
            }
        }
        if (searcher == 1){
            return true;
        } else {
            return false;
        }
    }

// Converts uints to strings. from https://github.com/willitscale/solidity-util/blob/master/lib/Integers.sol
    function intToString(uint _base) internal pure returns (string memory) {
        bytes memory _tmp = new bytes(32);
        uint i;
        for(i; _base > 0; i++) {
            _tmp[i] = byte(uint8((_base % 10) + 48));
            _base /= 10;
        }
        bytes memory _real = new bytes(i--);
        for(uint j; j < _real.length; j++) {
            _real[j] = _tmp[i--];
        }
        return string(_real);
    }

// Converts string to a uint from https://github.com/willitscale/solidity-util/blob/master/lib/Integers.sol
    function stringToInt(string memory _value) internal pure returns (uint _ret) {
        bytes memory _bytesValue = bytes(_value);
        uint j = 1;
        for(uint i = _bytesValue.length-1; i >= 0 && i < _bytesValue.length; i--) {
            assert(uint8(_bytesValue[i]) >= 48 && uint8(_bytesValue[i]) <= 57);
            _ret += (uint8(_bytesValue[i]) - 48)*j;
            j*=10;
        }
    }

// Compares two strings
    function compareStrings(
    	string memory a,
    	string memory b
    	) internal pure returns (bool){
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

// Converts string to bytes32
  	function stringToBytes32(string memory _string) internal pure returns (bytes32) {
   		bytes32 _stringBytes;
    	assembly {
      	_stringBytes := mload(add(_string, 32))
    	}
    	return _stringBytes;
  	}

// Converts bytes32 to string data type
	function bytes32toString(bytes32 _data) internal pure returns (string memory) {
    	bytes memory _bytesContainer = new bytes(32);
    	uint256 _charCount;
    	for (uint256 _bytesCounter; _bytesCounter < 32; _bytesCounter++) {
      		bytes1 _char = bytes1(bytes32(uint256(_data) * 2 ** (8 * _bytesCounter)));
      		if (_char != 0) {
        		_bytesContainer[_charCount] = _char;
       			_charCount++;
      		}
    	}
    	bytes memory _bytesContainerTrimmed = new bytes(_charCount);
    	for (uint256 _charCounter; _charCounter < _charCount; _charCounter++) {
      		_bytesContainerTrimmed[_charCounter] = _bytesContainer[_charCounter];
    	}
    	return string(_bytesContainerTrimmed);
 	}

} // END OF CONTRACT

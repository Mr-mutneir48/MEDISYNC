pragma solidity ^0.5.0;

contract MedicalChain {

    mapping(address => Doctor) public doctorInfo;
    mapping(address => Patient) public patientInfo;
    mapping(address => mapping(address => HealthRecords)) private healthInfo;
    mapping(address => mapping(address => uint)) private patientToDoctor;

    event DrDetailsAdded(address admin, address doctor);
    event HealthRecordsAdded(address dr, address patient);
    event GrantAccessToDr(address dr, address patient);
    event MedicalRecordUploaded(address patient, string record);
    event MedicalResearchContribution(address contributor);

    modifier OnlyOwner() {
        require(msg.sender == owner, "ONLY ADMIN IS ALLOWED");
        _;
    }

    modifier OnlyDoctors {
        require(doctorInfo[msg.sender].state == true, "REGISTERED DOCTORS ONLY");
        _;
    }

    modifier OnlyPatients {
        require(patientInfo[msg.sender].state == true, "REGISTERED PATIENTS ONLY");
        _;
    }

    address private owner;

    constructor() public {
        owner = msg.sender;
    }

    struct Doctor {
        bool state;
        address dr_Id;
        string d_Name;
    }

    struct Patient {
        bool state;
        address pa_Id;
        string pa_Name;
        string[] pa_Records;
    }

    struct PrescriptionDetails {
        string prescription;
    }

    struct HealthRecords {
        Doctor d;
        Patient p;
        PrescriptionDetails pre;
        string[] records;
    }

    mapping(address => string[]) private medicalRecords;
    mapping(address => mapping(address => bool)) private dataAccess;
    mapping(address => mapping(address => bool)) private accessRequests;
    mapping(address => string[]) private auditTrails;
    mapping(address => string) private healthReminders;
    mapping(address => bool) private researchContributors;
    mapping(address => mapping(address => uint)) private insuranceClaims;
    mapping(address => address) private emergencyAccessDoctors;
    mapping(address => string[]) private dataBackups;
    mapping(address => mapping(bytes32 => string)) private multiLanguageData;
    
    function setDoctorDetails(bool _state, address _drId, string memory _name) public OnlyOwner {
        doctorInfo[_drId] = Doctor(_state, _drId, _name);
        emit DrDetailsAdded(msg.sender, _drId);
    }

    function setHealthRecordsDetails(string memory _paName, address _paId, string memory _prescription) public OnlyDoctors {

        healthInfo[msg.sender][_paId].d.d_Name = doctorInfo[msg.sender].d_Name;
        healthInfo[msg.sender][_paId].d.dr_Id = doctorInfo[msg.sender].dr_Id;
        healthInfo[msg.sender][_paId].p.state = true;
        healthInfo[msg.sender][_paId].p.pa_Id = _paId;
        healthInfo[msg.sender][_paId].p.pa_Name = _paName;
        healthInfo[msg.sender][_paId].pre.prescription = _prescription;
        healthInfo[msg.sender][_paId].records.push(_prescription);
        patientInfo[_paId].pa_Records.push(_prescription);
        setPatientDetails(healthInfo[msg.sender][_paId].p.state, healthInfo[msg.sender][_paId].p.pa_Id, healthInfo[msg.sender][_paId].p.pa_Name, patientInfo[_paId].pa_Records);
        emit HealthRecordsAdded(msg.sender, _paId);
    }

    function setPatientDetails(bool _state, address _paId, string memory _paName, string[] memory _paRecords) public OnlyDoctors {
        patientInfo[_paId] = Patient(_state, _paId, _paName, _paRecords);
    }

    function grantAccessToDoctor(address doctor_id, uint access) public OnlyPatients {
        patientToDoctor[msg.sender][doctor_id] = access;
        emit GrantAccessToDr(doctor_id, msg.sender);
    }

    function optInForResearchContribution() public OnlyPatients {
        require(verifiedPatients[msg.sender], "Patient must be verified.");
        researchContributors[msg.sender] = true;
        emit MedicalResearchContribution(msg.sender);
    }

    function fileInsuranceClaim(address insuranceProvider, uint claimAmount) public OnlyPatients {
        require(verifiedPatients[msg.sender], "Patient must be verified.");
        insuranceClaims[msg.sender][insuranceProvider] = claimAmount;
    }

    function verifyInsuranceClaim(address patient, address insuranceProvider) public OnlyDoctors {
        require(verifiedDoctors[msg.sender], "Doctor must be verified.");
        insuranceClaims[patient][insuranceProvider] = 0;
    }

    function grantEmergencyAccess(address doctor) public OnlyPatients {
        require(verifiedPatients[msg.sender], "Patient must be verified.");
        emergencyAccessDoctors[msg.sender] = doctor;
    }

    function setHealthReminder(string memory reminder) public OnlyPatients {
        require(verifiedPatients[msg.sender], "Patient must be verified.");
        healthReminders[msg.sender] = reminder;
    }

    function backupMedicalData(string memory data) public OnlyPatients {
        require(verifiedPatients[msg.sender], "Patient must be verified.");
        dataBackups[msg.sender].push(data);
    }

    function generateMFA() public {
        uint code = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, blockhash(block.number - 1))));
        mfaCodes[msg.sender] = code;
    }

    function validateMFA(uint code) public view returns (bool) {
        return code == mfaCodes[msg.sender];
    }

    function setMultiLanguageData(bytes32 language, string memory data) public {
        multiLanguageData[msg.sender][language] = data;
    }

    function getMultiLanguageData(address user, bytes32 language) public view returns (string memory) {
        return multiLanguageData[user][language];
    }

    function uploadMedicalRecord(string memory record) public OnlyPatients {
        require(verifiedPatients[msg.sender], "Patient must be verified.");
        medicalRecords[msg.sender].push(record);
        emit MedicalRecordUploaded(msg.sender, record);
    }

    function shareMedicalRecord(address doctor, string memory record) public OnlyPatients {
        require(verifiedPatients[msg.sender], "Patient must be verified.");
        require(patientToDoctor[msg.sender][doctor] == 1, "Access not granted to doctor.");
        dataAccess[msg.sender][doctor] = true;
        auditTrails[msg.sender].push(record);
    }

    function getMedicalRecords(address user) public view returns (string[] memory) {
        require(verifiedPatients[msg.sender] || verifiedDoctors[msg.sender], "Access denied.");
        return medicalRecords[user];
    }

    function requestTelemedicine(address doctor) public OnlyPatients {
        require(verifiedPatients[msg.sender], "Patient must be verified.");
        telemedicineAppointments[msg.sender][doctor] = true;
    }

    function shareMedicalRecords(address doctor) public OnlyPatients {
        require(telemedicineAppointments[msg.sender][doctor], "No telemedicine appointment.");
        dataAccess[msg.sender][doctor] = true;
    }

    function trackHealthAnalytics(uint heartRate, uint bloodPressure) public OnlyPatients {
        require(verifiedPatients[msg.sender], "Patient must be verified.");
        HealthAnalytics storage analytics = patientAnalytics[msg.sender];
        analytics.heartRate = heartRate;
        analytics.bloodPressure = bloodPressure;
    }

    function getHealthAnalytics(address patient) public view returns (uint heartRate, uint bloodPressure) {
        HealthAnalytics storage analytics = patientAnalytics[patient];
        heartRate = analytics.heartRate;
        bloodPressure = analytics.bloodPressure;
    }

    function downloadMedicalRecords() public OnlyPatients {
        require(verifiedPatients[msg.sender], "Patient must be verified.");
        string[] storage records = medicalRecords[msg.sender];
        for (uint i = 0; i < records.length; i++) {
            downloadedRecords[msg.sender].push(records[i]);
        }
    }

    function getDownloadedRecords(address patient) public view returns (string[] memory) {
        return downloadedRecords[patient];
    }
}

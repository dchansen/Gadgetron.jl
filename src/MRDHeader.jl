using  AcuteML
using Dates: Time, Date


export MRDHeader


@enm PatientGender M F O

@aml mutable struct SubjectInformation "~"
    patientName::UN{String}=nothing, "~"
    patientWeight_kg::UN{Float32}=nothing, "~"
    patientID::UN{String}=nothing, "~"
    patientBirthdate::UN{Date}=nothing, "~"
    patientGender::UN{PatientGender.Enm}=nothing, "~" 
end
@aml mutable struct StudyInformation "~"
    studyDate::UN{Date}=nothing, "~"
    studyTime::UN{Time}=nothing, "~"
    studyID::UN{String}=nothing, "~"
    accessionNumber::UN{Int64}=nothing, "~"
    referringPhysicianName::UN{String}=nothing, "~"
    studyDescription::UN{String}=nothing, "~"
    studyInstanceUID::UN{String}=nothing, "~"
end


@enm PatientPosition HFP HFS HFDR HFDL FFP FFS FFDR FFDL

@aml mutable struct MeasurementDependency "~"
    dependencyType::String, "~"
    measurementID::String, "~"
end
@aml mutable struct ReferencedImageSequence "~"
    referencedSOPInstanceUID::UN{Vector{String}}=nothing, "~"
end
@aml mutable struct MeasurementInformation "~"
    measurementID::UN{String}=nothing, "~"
    seriesDate::UN{Date}=nothing, "~"
    seriesTime::UN{Time}=nothing, "~"
    patientPosition::PatientPosition.Enm, "~"
    initialSeriesNumber::UN{Int64}=nothing, "~"
    protocolName::UN{String}=nothing, "~"
    seriesDescription::UN{String}=nothing, "~"
    measurementDependency::UN{Vector{MeasurementDependency}}=nothing, "~"
    seriesInstanceUIDRoot::UN{String}=nothing, "~"
    frameOfReferenceUID::UN{String}=nothing, "~"
    referenceImageSequence::UN{ReferencedImageSequence}=nothing, "~"
end

@aml mutable struct CoilLabel "~"
    coilNumber::UInt16,"~"
    coilName::String,"~"
end


@aml mutable struct AcquisitionSystemInformation "~"
    systemVendor::UN{String}=nothing, "~"
    systemModel::UN{String}=nothing, "~"
    systemFieldStrength_T::UN{Float32}=nothing, "~"
    relativeReceiverNoiseBandwidth::UN{Float32}=nothing, "~"
    receiverChannels::UN{UInt16}=nothing, "~"
    coilLabel::UN{Vector{CoilLabel}}=nothing,"~"
    institutionName::UN{String}=nothing, "~"
    stationName::UN{String}=nothing, "~"
    deviceID::UN{String}= nothing, "~"
end 
@aml mutable struct ExperimentalConditions "~"
    H1resonanceFrequency_Hz::Int64, "~"
end

@aml mutable struct UserParameter{T} "~"
    name::String, "~"
    value::T, "~"
end 



@enm TrajectoryType cartesian epi radial goldenangle spiral other 

@aml mutable struct TrajectoryDescription "~"
    identifier::String, "~"
    userParameterLong::UN{Vector{UserParameter{Int64}}}=nothing, "~"
    userParameterDouble::UN{Vector{UserParameter{Float64}}}=nothing, "~"
    comment::UN{String}=nothing, "~"
end

@aml mutable struct AccelerationFactor "~"
    kspace_encoding_step_1::UInt16, "~"
    kspace_encoding_step_2::UInt16, "~"
end

@enm InterleavingDimension phase repetition contrast average other 



@enm CalibrationMode embedder interleaved separate external other 

@aml mutable struct ParallelImaging  "~"
    accelerationFactor::AccelerationFactor, "~"
    calibrationMode::UN{CalibrationMode.Enm}, "~"
    interleavingDimension::UN{InterleavingDimension.Enm}, "~" 
end

@aml mutable struct MatrixSize "~"
    x::UInt16=1, "~"
    y::UInt16=1, "~"
    z::UInt16=1, "~"
end

@aml mutable struct FieldOfView_mm "~"
    x::Float32, "~"
    y::Float32, "~"
    z::Float32, "~"

end

@aml mutable struct EncodingSpace "~"
    matrixSize::MatrixSize, "~"
    fieldOfView_mm::FieldOfView_mm, "~"
end

@aml mutable struct Limit "~"
    minimum::UInt16=0, "~"
    maximum::UInt16=0, "~"
    center::UInt16=0, "~"
end

@aml mutable struct EncodingLimits "~"
    kspace_encoding_step_0::UN{Limit}=nothing, "~"
    kspace_encoding_step_1::UN{Limit}=nothing, "~"
    kspace_encoding_step_2::UN{Limit}=nothing, "~"
    average::UN{Limit}=nothing, "~"
    slice::UN{Limit}=nothing, "~"
    contrast::UN{Limit}=nothing, "~"
    phase::UN{Limit}=nothing, "~"
    repetition::UN{Limit}=nothing, "~"
    set::UN{Limit}=nothing, "~"
    segment::UN{Limit}=nothing, "~"
end



@aml mutable struct Encoding "~"
    encodedSpace::EncodingSpace, "~"
    reconSpace::EncodingSpace, "~"
    encodingLimits::EncodingLimits,"~"
    trajectory::TrajectoryType.Enm,"~"
    trajectoryDescription::UN{TrajectoryDescription}=nothing,"~"
    parallelImaging::UN{ParallelImaging}=nothing,"~"
    echoTrainLength::UN{Int64}, "~"
end

@aml mutable struct SequenceParameters "~"
    TR::UN{Vector{Float32}}=nothing, "~"
    TE::UN{Vector{Float32}}=nothing, "~"
    TI::UN{Vector{Float32}}=nothing, "~"
    flipAngle_deg::UN{Vector{Float32}}=nothing, "~"
    sequence_type::UN{String}=nothing, "~"
    echo_spacing::UN{Vector{Float32}}=nothing, "~"
end



@aml mutable struct UserParameters "~"
    userParameterLong::UN{Vector{UserParameter{Int64}}}=nothing,"~"
    userParameterDouble::UN{Vector{UserParameter{Float64}}}=nothing,"~"
    userParameterString::UN{Vector{UserParameter{String}}}=nothing,"~"
    userParameterBase64::UN{Vector{UserParameter{String}}}=nothing,"~"
end 

@enm WaveformType ecg pulse respiratory trigger gradientwaveform other 


@aml mutable struct WaveformInformation "~"
    waveformName::String, "~"
    waveformType::WaveformType.Enm, "~"
    userParameters::UserParameters, "~"
end


@aml mutable struct MRDHeader doc"ismrmrdHeader"
    version::UN{Int}=nothing, "~"
    subjectInformation::UN{SubjectInformation}=nothing, "~"
    studyInformation::UN{StudyInformation}=nothing, "~"
    measurementInformation::UN{MeasurementInformation}=nothing, "~"
    acquisitionSystemInformation::UN{AcquisitionSystemInformation}=nothing, "~"
    experimentalConditions::ExperimentalConditions, "~"
    encoding::UN{Vector{Encoding}}=nothing, "~"
    sequenceParameters::UN{SequenceParameters}=nothing, "~"
    userParameters::UN{UserParameters}=nothing, "~"
    waveformInformation::UN{WaveformInformation}=nothing, "~"
end

	

    

MRDHeader(x::AbstractString) = x |> parsexml |> MRDHeader
precompile(Tuple{typeof(MRDHeader),String})


    

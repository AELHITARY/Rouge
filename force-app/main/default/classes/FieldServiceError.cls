//-- *
//-- Fichier     : FieldServiceError
//-- Modifié par : CGI - FSL
//-- Modifié le  : 13/04/2018
//-- Description : Classe utilitaire permettant de gérer les erreurs de type Exception et Database.error
//-- Version     : 1.0
//-- --------------------------------------------------------------------------------- --
public with sharing class FieldServiceError {
    
	public class DMLError{
        Public string errorEtape{get ;set ;}
		Public string errorMsg{get ;set ;}
		Public StatusCode errorCode{get ;set ;}
		Public string[] fields {get;set;}	
		
			Public DMLError(Database.Error erreurDB, String et){
                this.errorEtape = et; 
                this.errorMsg = erreurDB.getMessage();
				this.errorCode = erreurDB.getStatusCode();
				this.fields = erreurDB.getFields();
			}
		}
    
        public class ExceptError{
            Public string errorEtape{get ;set ;}
            Public string errorMsg{get ;set ;}
            Public string errorType{get ;set ;}
            Public Exception errorCause{get ;set ;}
            Public integer errorLineNumber{get ;set ;}
            Public string errorTrace{get ;set ;}

            Public ExceptError(Exception erreurEx, String et){
                this.errorEtape = et; 
                this.errorMsg = erreurEx.getMessage();
                this.errorType = erreurEx.getTypeName();
                this.errorCause = erreurEx.getCause();
                this.errorLineNumber = erreurEx.getLineNumber();
                this.errorTrace = erreurEx.getStackTraceString();
            }
        }
	
        Public List<DMLError>  errorDML {get;set;}
        Public List<ExceptError> errorException  {get;set;}
        
        public FieldServiceError() {
            this.errorDML = new List<DMLError>() ;
            this.errorException = new List<ExceptError>() ;
        }
        
        public FieldServiceError(List<Database.error> err, List<ExceptError> e, String et) {
            if (err != null){
                for ( Database.error er : err){
                    DMLError d = new DMLError(er,et);
                    this.errorDML.add(d);
                }
            }
            this.errorException = e;
        }
        
        public FieldServiceError(List<ExceptError> e, String et) {
            this.errorDML = new List<DMLError>() ;
            this.errorException = e;       
        }
        
        public void addDMLError(List<Database.error> err, String et) {
            if (err != null){
                for ( Database.error er : err){
                    DMLError d = new DMLError(er,et);
                    this.errorDML.add(d);
                }
            }
        }  
        
        public void addDMLError(List<DMLError> errList) {
            this.errorDML.addAll(errList);
        }
        
        public void addDMLError(Database.error err, String et) {
            DMLError d = new DMLError(err,et);
            this.errorDML.add(d);
        }
        
        public void addExeptionError(List<ExceptError> errList) {
            (this.errorException).addAll(errList);
        }
        
        public void addExeptionError(ExceptError err) {
            this.errorException.add(err);
        }
    
         public void addExeptionError(Exception err, String et) {
            if (err != null){   
                ExceptError d = new ExceptError(err,et);
                this.errorException.add(d);            
            }        
         }
    
        public void combineError(FieldServiceError err) {
            if(err.errorException != null && (err.errorException).size() > 0)
                this.addExeptionError(err.errorException);
            if(err.errorDML != null && (err.errorDML).size() > 0)
                this.addDMLError(err.errorDML);
        }
        
        public String getMessage() {
            String message = '';
            
            if (this.errorException  != null && this.errorException.size() > 0){
                for (ExceptError e : this.errorException){
                    if(!''.equals(e.errorMsg)){
                       message = message+'Etape = '+ e.errorEtape+ '\n'
                            +' Message = ' + e.errorMsg+ '\n'
                            + 'Type = ' + e.errorType + '\n'
                            + 'Cause = ' + e.errorCause+ '\n'
                            + 'Ligne = ' + e.errorLineNumber + '\n'
                            + e.errorTrace+ '\n\n'; 
                    }             
                }	
            }
            
            if (this.errorDML  != null && this.errorDML.size() > 0){
                for(DMLError err : this.errorDML ) {
                    if(!''.equals(err.errorMsg)){
                        message = message+'Etape = ' + err.errorEtape + '\n'
                            +'Message = ' + err.errorMsg + '\n'
                            + 'Statut = ' + err.errorCode + '\n'
                            + 'Champs = ' + err.fields + '\n\n';
                    }
                }
            }
            return message;
        }
 }
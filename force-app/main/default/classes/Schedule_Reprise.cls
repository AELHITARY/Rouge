global class Schedule_Reprise implements Schedulable{

    global void execute(SchedulableContext context) {
        BA_RepriseLigneDevis batch = new BA_RepriseLigneDevis();
        Id batchId = Database.executeBatch(batch);
    }
}
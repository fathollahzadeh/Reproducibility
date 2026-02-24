SELECT 
    (SELECT COUNT(DISTINCT OwnerUserId) FROM Posts WHERE PostTypeId = 1) AS TotalQuestions,
    (SELECT COUNT(DISTINCT OwnerUserId) FROM Posts WHERE PostTypeId = 2) AS TotalAnswers
;
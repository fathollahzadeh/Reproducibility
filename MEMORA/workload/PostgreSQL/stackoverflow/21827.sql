
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionsAnswered
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
QuestionActivity AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.AcceptedAnswerId,
        COALESCE(PH.CreationDate, P.CreationDate) AS ActivityDate,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS LatestEditRank
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.PostTypeId = 1
),
FilteredQuestions AS (
    SELECT 
        QA.PostId,
        QA.Title,
        QA.ActivityDate,
        U.UserId,
        U.DisplayName,
        U.TotalUpVotes,
        U.TotalDownVotes,
        U.QuestionsAnswered,
        CASE 
            WHEN AQ.Id IS NOT NULL THEN 'Accepted'
            ELSE 'Not Accepted' 
        END AS AcceptanceStatus
    FROM 
        QuestionActivity QA
    JOIN 
        UserVoteSummary U ON QA.PostId = U.UserId
    LEFT JOIN 
        Posts AQ ON QA.AcceptedAnswerId = AQ.Id
    WHERE 
        QA.LatestEditRank = 1
),
FinalSummary AS (
    SELECT 
        FQ.Title,
        FQ.DisplayName, 
        FQ.TotalUpVotes,
        FQ.TotalDownVotes,
        FQ.QuestionsAnswered,
        FQ.ActivityDate,
        FQ.AcceptanceStatus,
        CASE 
            WHEN FQ.TotalUpVotes IS NULL OR FQ.TotalDownVotes IS NULL THEN 'Data Incomplete'
            ELSE 'Complete Data'
        END AS DataCompleteness
    FROM 
        FilteredQuestions FQ
)
SELECT 
    Title,
    DisplayName,
    TotalUpVotes,
    TotalDownVotes,
    QuestionsAnswered,
    ActivityDate,
    AcceptanceStatus,
    DataCompleteness
FROM 
    FinalSummary
WHERE 
    DataCompleteness = 'Complete Data'
ORDER BY 
    QuestionsAnswered DESC, TotalUpVotes DESC;


WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT C.Id), 0) AS CommentCount,
        COALESCE(COUNT(DISTINCT P.Id), 0) AS PostCount,
        COALESCE(SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END), 0) AS AcceptedAnswers
    FROM 
        Users U
        LEFT JOIN Votes V ON U.Id = V.UserId
        LEFT JOIN Posts P ON U.Id = P.OwnerUserId
        LEFT JOIN Comments C ON C.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),

TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        UpVotes,
        DownVotes,
        CommentCount,
        PostCount,
        AcceptedAnswers,
        DENSE_RANK() OVER (ORDER BY UpVotes DESC) AS RankByUpVotes
    FROM 
        UserActivity
    WHERE 
        PostCount > 0
),

CloseReasonSummary AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS CloseCount,
        STRING_AGG(CASE 
                      WHEN CRT.Name IS NOT NULL THEN CRT.Name 
                      ELSE 'Unknown' 
                   END, ', ') AS CloseReasons
    FROM 
        PostHistory PH
        LEFT JOIN CloseReasonTypes CRT ON CAST(PH.Comment AS INTEGER) = CRT.Id
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.UserId
)

SELECT 
    TU.DisplayName,
    TU.UpVotes,
    TU.DownVotes,
    TU.CommentCount,
    TU.PostCount,
    TU.AcceptedAnswers,
    CRS.CloseCount,
    CRS.CloseReasons,
    CASE 
        WHEN TU.AcceptedAnswers > 0 THEN 'Has Accepted Answers'
        ELSE 'No Accepted Answers'
    END AS AnswerStatus,
    CASE 
        WHEN TU.RankByUpVotes <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorStatus
FROM 
    TopUsers TU
    LEFT JOIN CloseReasonSummary CRS ON TU.UserId = CRS.UserId
WHERE 
    TU.RankByUpVotes <= 20 OR CRS.CloseCount > 0
ORDER BY 
    TU.RankByUpVotes
LIMIT 10 OFFSET 5;

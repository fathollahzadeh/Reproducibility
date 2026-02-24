WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN P.PostTypeId = 2 AND P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation IS NOT NULL
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation, U.Views, U.UpVotes, U.DownVotes
),
MostActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        Rank
    FROM 
        UserStats
    WHERE 
        PostCount > 0
),
ClosedPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS ClosedPostCount
    FROM 
        Posts P
    INNER JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        PH.PostHistoryTypeId = 10 
    GROUP BY 
        P.OwnerUserId
),
UserReputationChanges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        MAX(PH.CreationDate) AS LastActivityDate,
        COUNT(PH.Id) AS EditCount
    FROM 
        Users U
    LEFT JOIN 
        PostHistory PH ON U.Id = PH.UserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    M.DisplayName,
    M.Reputation,
    M.Rank,
    COALESCE(CP.ClosedPostCount, 0) AS ClosedPostCount,
    COALESCE(UC.EditCount, 0) AS EditCount,
    CASE 
        WHEN M.Rank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    MostActiveUsers M
LEFT JOIN 
    ClosedPosts CP ON M.UserId = CP.OwnerUserId
LEFT JOIN 
    UserReputationChanges UC ON M.UserId = UC.UserId
ORDER BY 
    M.Rank;
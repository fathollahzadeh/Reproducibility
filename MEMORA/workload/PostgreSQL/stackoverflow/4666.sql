WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.UpVotes,
        U.DownVotes,
        (U.UpVotes - U.DownVotes) AS NetVotes,
        RANK() OVER (ORDER BY (U.UpVotes - U.DownVotes) DESC) AS RankPosition
    FROM 
        Users U
), 
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
UserPerformance AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        U.NetVotes,
        PS.PostCount,
        PS.QuestionCount,
        PS.AnswerCount,
        COALESCE(PS.PostCount, 0) * 1.0 / NULLIF((SELECT COUNT(*) FROM Posts), 0) AS PostContribution
    FROM 
        UserScore U
    LEFT JOIN 
        PostStats PS ON U.UserId = PS.OwnerUserId
)
SELECT 
    UP.DisplayName,
    UP.Reputation,
    UP.NetVotes,
    UP.PostCount,
    UP.QuestionCount,
    UP.AnswerCount,
    UP.PostContribution,
    CASE 
        WHEN UP.Reputation > 1000 THEN 'High Contributor'
        WHEN UP.Reputation BETWEEN 500 AND 1000 THEN 'Moderate Contributor'
        ELSE 'New Contributor'
    END AS ContributorStatus
FROM 
    UserPerformance UP
WHERE 
    UP.PostCount > 5
ORDER BY 
    UP.NetVotes DESC, 
    UP.Reputation DESC
LIMIT 10;
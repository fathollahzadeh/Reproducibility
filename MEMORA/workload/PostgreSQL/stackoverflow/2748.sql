WITH UserEngagement AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(COALESCE(VUp.VoteCount, 0)) AS TotalUpVotes,
        SUM(COALESCE(VDown.VoteCount, 0)) AS TotalDownVotes,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM Votes 
        WHERE VoteTypeId = 2
        GROUP BY PostId
    ) VUp ON P.Id = VUp.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS VoteCount
        FROM Votes 
        WHERE VoteTypeId = 3
        GROUP BY PostId
    ) VDown ON P.Id = VDown.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM Comments 
        GROUP BY PostId
    ) C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
), UserRanked AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM UserEngagement
)
SELECT 
    U.*,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN UserRank <= 10 THEN 'Top Contributor'
        WHEN Reputation >= 1000 THEN 'Experienced User'
        ELSE 'Newcomer'
    END AS UserStatus
FROM UserRanked U
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount
    FROM Badges 
    GROUP BY UserId
) B ON U.UserId = B.UserId
WHERE U.TotalUpVotes > U.TotalDownVotes
ORDER BY U.Reputation DESC
LIMIT 100;

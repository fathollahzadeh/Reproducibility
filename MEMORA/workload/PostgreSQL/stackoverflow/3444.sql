
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(V.VoteCount, 0)) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount, VoteTypeId
        FROM Votes
        GROUP BY PostId, VoteTypeId
    ) V ON P.Id = V.PostId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(P.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        MAX(P.CreationDate) AS LatestActivity,
        P.OwnerUserId
    FROM 
        Posts P 
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title, P.AcceptedAnswerId, P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.TotalVotes,
    U.UpVotes,
    U.DownVotes,
    B.BadgeNames,
    B.BadgeCount,
    P.Title,
    P.CommentCount,
    P.LatestActivity,
    CASE 
        WHEN P.AcceptedAnswerId > 0 THEN 'Accepted Answer Available' 
        ELSE 'No Accepted Answer' 
    END AS AnswerStatus
FROM 
    UserStats U
LEFT JOIN 
    TopBadges B ON U.UserId = B.UserId
LEFT JOIN 
    PostSummary P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC, 
    U.TotalVotes DESC
LIMIT 10;

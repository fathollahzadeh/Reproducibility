
WITH PostStatistics AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        SUM(V.BountyAmount) AS TotalBounty,
        U.Reputation AS OwnerReputation,
        P.LastActivityDate,
        P.Score,
        P.OwnerUserId
    FROM
        Posts P
    LEFT JOIN
        Posts A ON P.Id = A.ParentId AND P.PostTypeId = 1
    LEFT JOIN
        Votes V ON P.Id = V.PostId AND V.VoteTypeId = 9  
    LEFT JOIN
        Users U ON P.OwnerUserId = U.Id
    GROUP BY
        P.Id, P.Title, P.CreationDate, P.ViewCount, U.Reputation, P.LastActivityDate, P.Score, P.OwnerUserId
),
UserStatistics AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM
        Users U
    LEFT JOIN
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN
        Badges B ON U.Id = B.UserId
    GROUP BY
        U.Id, U.DisplayName
)

SELECT
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.AnswerCount,
    PS.TotalBounty,
    PS.OwnerReputation,
    PS.LastActivityDate,
    PS.Score,
    US.UserId,
    US.DisplayName AS OwnerDisplayName,
    US.TotalPosts,
    US.TotalUpVotes,
    US.TotalDownVotes,
    US.TotalBadges
FROM
    PostStatistics PS
JOIN
    UserStatistics US ON PS.OwnerUserId = US.UserId
ORDER BY
    PS.ViewCount DESC
LIMIT 100;

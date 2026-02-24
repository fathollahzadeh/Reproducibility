
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 2) AS UpVoteCount,
        COUNT(V.Id) FILTER (WHERE V.VoteTypeId = 3) AS DownVoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE -1 END) AS NetVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.ViewCount, 0) AS ViewCount,
        (
            SELECT 
                COUNT(Comment.Id) 
            FROM 
                Comments Comment 
            WHERE 
                Comment.PostId = P.Id
        ) AS TotalComments,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
),
PostVoteCount AS (
    SELECT 
        P.Id AS PostId,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
),
EngagementMetrics AS (
    SELECT 
        S.UserId,
        COALESCE(MAX(PC.VoteCount), 0) AS MaxPostVotes,
        COALESCE(SUM(PS.ViewCount), 0) AS TotalPostViews,
        COALESCE(SUM(PS.TotalComments), 0) AS TotalComments
    FROM 
        UserVoteStats S
    LEFT JOIN 
        PostStats PS ON S.UserId = PS.OwnerUserId
    LEFT JOIN 
        PostVoteCount PC ON PS.PostId = PC.PostId
    GROUP BY 
        S.UserId
)
SELECT 
    U.Id AS UserId,
    U.DisplayName,
    U.Reputation,
    EU.UpVoteCount,
    EU.DownVoteCount,
    EU.NetVotes,
    EM.MaxPostVotes,
    EM.TotalPostViews,
    EM.TotalComments,
    CASE 
        WHEN EM.TotalComments > 10 THEN 'Highly Engaged'
        WHEN EM.TotalPostViews > 100 THEN 'Popular'
        WHEN EM.MaxPostVotes > 5 THEN 'Influencer'
        ELSE 'Novice'
    END AS EngagementLevel
FROM 
    Users U
JOIN 
    UserVoteStats EU ON U.Id = EU.UserId
LEFT JOIN 
    EngagementMetrics EM ON U.Id = EM.UserId
WHERE 
    U.Reputation > 100
ORDER BY 
    EU.NetVotes DESC,
    EM.TotalPostViews DESC
LIMIT 50;

WITH RECURSIVE UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CreationDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        Users 
), 
PostMetrics AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.Score,
        Posts.CreationDate,
        COUNT(DISTINCT Comments.Id) AS TotalComments,
        COUNT(DISTINCT Votes.Id) AS TotalVotes,
        SUM(CASE 
            WHEN Votes.VoteTypeId = 2 THEN 1 
            ELSE 0 END) AS Upvotes,
        SUM(CASE 
            WHEN Votes.VoteTypeId = 3 THEN 1 
            ELSE 0 END) AS Downvotes,
        AVG(Users.Reputation) AS AvgUserReputation
    FROM 
        Posts 
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId 
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    LEFT JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    WHERE 
        Posts.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        Posts.Id, Posts.Title, Posts.Score, Posts.CreationDate
), 
ClosedPostHistory AS (
    SELECT 
        PostId,
        MAX(CASE 
            WHEN PostHistoryTypeId = 10 THEN CreationDate 
            ELSE NULL END) AS LastClosedDate,
        MAX(CASE 
            WHEN PostHistoryTypeId = 11 THEN CreationDate 
            ELSE NULL END) AS LastReopenedDate
    FROM 
        PostHistory
    GROUP BY 
        PostId
)
SELECT 
    P.PostId,
    P.Title,
    P.Score,
    P.TotalComments,
    P.TotalVotes,
    COALESCE(P.AvgUserReputation, 0) AS AvgUserReputation,
    C.LastClosedDate,
    C.LastReopenedDate,
    CASE 
        WHEN C.LastClosedDate IS NOT NULL AND (C.LastReopenedDate IS NULL OR C.LastClosedDate > C.LastReopenedDate) THEN 'Closed'
        WHEN C.LastReopenedDate IS NOT NULL THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM 
    PostMetrics P
LEFT JOIN 
    ClosedPostHistory C ON P.PostId = C.PostId
ORDER BY 
    P.Score DESC, P.TotalVotes DESC
LIMIT 50;
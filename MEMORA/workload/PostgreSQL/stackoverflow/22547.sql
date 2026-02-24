WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.PostTypeId,
        COALESCE(c.CommentCount, 0) AS TotalComments,
        COALESCE(voteSum.VoteSum, 0) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON c.PostId = p.Id
    LEFT JOIN 
        (SELECT PostId, SUM(CASE WHEN VoteTypeId IN (2, 8) THEN 1 WHEN VoteTypeId = 3 THEN -1 ELSE 0 END) AS VoteSum
         FROM Votes GROUP BY PostId) voteSum ON voteSum.PostId = p.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND 
        p.Score > 0
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1 
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        u.Id
),
RecentComments AS (
    SELECT 
        PostId,
        COUNT(*) AS RecentCommentCount
    FROM
        Comments
    WHERE 
        CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        PostId
),
FinalResults AS (
    SELECT 
        r.PostId,
        r.Title,
        r.Score,
        r.Rank,
        r.TotalComments,
        a.UserId,
        a.DisplayName,
        a.Reputation,
        a.PostCount,
        a.TotalBadges,
        COALESCE(rc.RecentCommentCount, 0) AS RecentComments,
        CASE 
            WHEN a.Reputation IS NULL THEN 'Inactive User'
            ELSE 'Active User'
        END AS UserStatus
    FROM 
        RankedPosts r
    JOIN 
        ActiveUsers a ON r.PostId = a.UserId
    LEFT JOIN 
        RecentComments rc ON rc.PostId = r.PostId
)
SELECT 
    PostId,
    Title,
    Score,
    Rank,
    TotalComments,
    UserId,
    DisplayName,
    Reputation,
    PostCount,
    TotalBadges,
    RecentComments,
    UserStatus
FROM 
    FinalResults
ORDER BY 
    Score DESC, Rank ASC
LIMIT 50;
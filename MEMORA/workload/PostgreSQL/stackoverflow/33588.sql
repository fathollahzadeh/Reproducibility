
WITH RECURSIVE UserReputationCTE AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        0 AS Level
    FROM 
        Users
    WHERE 
        Reputation IS NOT NULL

    UNION ALL

    SELECT 
        u.Id, 
        u.Reputation, 
        urc.Level + 1
    FROM 
        Users u
    INNER JOIN 
        UserReputationCTE urc ON u.Reputation > urc.Reputation
),
PostTagsCTE AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),
RecentVotes AS (
    SELECT 
        PostId,
        COUNT(*) FILTER (WHERE VoteTypeId = 2) AS Upvotes,
        COUNT(*) FILTER (WHERE VoteTypeId = 3) AS Downvotes
    FROM 
        Votes
    WHERE 
        CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY 
        PostId
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MIN(ph.CreationDate) AS FirstActionDate,
        MAX(ph.CreationDate) AS LastActionDate,
        COUNT(*) AS ActionCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS IsClosed,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS IsReopened
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    COALESCE(rt.Upvotes, 0) AS RecentUpvotes,
    COALESCE(rt.Downvotes, 0) AS RecentDownvotes,
    COALESCE(hs.IsClosed, 0) AS IsClosed,
    COALESCE(hs.IsReopened, 0) AS IsReopened,
    COUNT(DISTINCT c.Id) AS CommentCount,
    STRING_AGG(DISTINCT tt.Tag, ', ') AS Tags,
    u.DisplayName,
    u.Reputation AS UserReputation
FROM 
    Posts p
LEFT JOIN 
    RecentVotes rt ON p.Id = rt.PostId
LEFT JOIN 
    PostHistorySummary hs ON p.Id = hs.PostId
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    PostTagsCTE tt ON p.Id = tt.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
GROUP BY 
    p.Id, p.Title, p.Score, rt.Upvotes, rt.Downvotes, hs.IsClosed, hs.IsReopened, u.Id, u.DisplayName
ORDER BY 
    p.Score DESC, p.CreationDate DESC
LIMIT 100;

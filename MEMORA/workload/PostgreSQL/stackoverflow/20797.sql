WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank,
        COALESCE(UPPER(p.OwnerDisplayName), 'Anonymous') AS OwnerDisplayName
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), 
PostMetrics AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryDate,
        ph.Comment,
        EXTRACT(EPOCH FROM (cast('2024-10-01 12:34:56' as timestamp) - ph.CreationDate)) AS AgeInSeconds,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Close'
            ELSE 'Edit'
        END AS ActionType
    FROM 
        RankedPosts rp 
    LEFT JOIN 
        PostHistory ph ON rp.PostId = ph.PostId
    WHERE 
        rp.PostRank <= 5
),
UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount,
        SUM(pt.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.OwnerDisplayName,
    pm.Score,
    pm.ViewCount,
    pm.ActionType,
    pm.HistoryDate,
    pm.Comment,
    pm.AgeInSeconds,
    uvs.DisplayName AS UserVoteDisplayName,
    uvs.Upvotes,
    uvs.Downvotes,
    uvs.NetVotes,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews
FROM 
    PostMetrics pm
LEFT JOIN 
    UserVoteStats uvs ON uvs.UserId = pm.PostId 
LEFT JOIN 
    TagStats ts ON pm.Title LIKE '%' || ts.TagName || '%'
WHERE 
    pm.ViewCount > 100
ORDER BY 
    pm.Score DESC, 
    pm.HistoryDate ASC
FETCH FIRST 100 ROWS ONLY;

WITH RECURSIVE UserRankings AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CreationDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        Users
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.Tags, u.DisplayName
),
PostHistories AS (
    SELECT 
        ph.PostId,
        pht.Name AS PostHistoryType,
        ph.CreationDate AS HistoryDate,
        ph.UserDisplayName,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.VoteCount,
    ur.Reputation AS OwnerReputation,
    ur.Rank AS OwnerRank,
    ph.PostHistoryType,
    ph.HistoryDate,
    ph.UserDisplayName AS Editor,
    ph.HistoryRank
FROM 
    RecentPosts rp
LEFT JOIN 
    UserRankings ur ON rp.OwnerDisplayName = ur.DisplayName
LEFT JOIN 
    PostHistories ph ON rp.PostId = ph.PostId AND ph.HistoryRank = 1
WHERE 
    rp.Score > 5
    AND rp.CommentCount > 0
    AND (rp.Tags ILIKE '%sql%' OR rp.Tags ILIKE '%database%')
ORDER BY 
    rp.ViewCount DESC, 
    rp.Score DESC;

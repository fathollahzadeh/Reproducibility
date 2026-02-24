
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '>')) AS t(TagName) ON TRUE
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount
), 
BestPosts AS (
    SELECT 
        PostID,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        Tags,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    bp.PostID,
    bp.Title,
    bp.CreationDate,
    bp.Score,
    bp.ViewCount,
    bp.OwnerDisplayName,
    bp.Tags,
    bh.Name AS PostHistoryType,
    COUNT(bh.Id) AS HistoryChangeCount
FROM 
    BestPosts bp
LEFT JOIN 
    PostHistory ph ON bp.PostID = ph.PostId 
LEFT JOIN 
    PostHistoryTypes bh ON ph.PostHistoryTypeId = bh.Id
GROUP BY 
    bp.PostID, bp.Title, bp.CreationDate, bp.Score, bp.ViewCount, bp.OwnerDisplayName, bp.Tags, bh.Name
ORDER BY 
    bp.Score DESC, HistoryChangeCount DESC;

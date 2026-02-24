WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.Id END) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.Id END) AS DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS ViewRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        r.*,
        COALESCE(CAST(SUBSTRING(r.Body FROM 1 FOR 300) AS VARCHAR(300)), '-') || '...' AS PreviewBody
    FROM 
        RankedPosts r
    WHERE 
        r.UpVoteCount > 10 AND r.CommentCount > 5
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.PreviewBody,
    fp.CreationDate,
    fp.ViewCount,
    fp.OwnerDisplayName,
    fp.UpVoteCount,
    fp.DownVoteCount,
    COUNT(DISTINCT ph.Id) AS EditHistoryCount,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostHistoryTypes
FROM 
    FilteredPosts fp
LEFT JOIN 
    PostHistory ph ON fp.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
GROUP BY 
    fp.PostId, fp.Title, fp.PreviewBody, fp.CreationDate, fp.ViewCount, fp.OwnerDisplayName, fp.UpVoteCount, fp.DownVoteCount
ORDER BY 
    fp.ViewCount DESC
LIMIT 50;
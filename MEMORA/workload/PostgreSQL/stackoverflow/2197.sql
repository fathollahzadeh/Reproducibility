
WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END), 0) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COALESCE(pc.CommentCount, 0) AS CommentCount,
        COALESCE(pe.EditCount, 0) AS EditCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) pc ON p.Id = pc.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS EditCount 
        FROM 
            PostHistory 
        WHERE 
            PostHistoryTypeId IN ('5', '24')
        GROUP BY 
            PostId
    ) pe ON p.Id = pe.PostId
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.ViewCount,
        ps.Score,
        ps.CommentCount,
        ps.EditCount,
        RANK() OVER (ORDER BY ps.ViewCount DESC) AS ViewRank
    FROM 
        PostSummary ps 
    WHERE 
        ps.RowNum = 1
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    ups.TotalVotes,
    CASE 
        WHEN ups.TotalVotes > 100 THEN 'Popular'
        WHEN ups.TotalVotes BETWEEN 51 AND 100 THEN 'Moderate'
        ELSE 'Less Popular'
    END AS PopularityCategory
FROM 
    UserVoteSummary ups
JOIN 
    Votes v ON ups.UserId = v.UserId 
JOIN 
    TopPosts tp ON tp.PostId = v.PostId
WHERE 
    (tp.EditCount > 5 OR tp.CommentCount > 10)
    AND (SELECT COUNT(*) FROM Votes WHERE PostId = tp.PostId AND VoteTypeId = 2) > 10
ORDER BY 
    ups.TotalVotes DESC, 
    tp.ViewCount DESC;

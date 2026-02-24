
WITH PostAnalysis AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        MAX(v.CreationDate) AS LastVoteDate,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        (SELECT COUNT(*)
         FROM PostHistory ph
         WHERE ph.PostId = p.Id AND ph.PostHistoryTypeId IN (10, 11)) AS CloseReopenCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(DISTINCT c.Id) DESC) AS OwnerRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR' 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.OwnerUserId
),
RankedPosts AS (
    SELECT 
        pa.PostId,
        pa.Title,
        pa.Tags,
        pa.CommentCount,
        pa.AnswerCount,
        pa.LastVoteDate,
        pa.Upvotes,
        pa.Downvotes,
        pa.CloseReopenCount,
        pa.OwnerRank,
        RANK() OVER (ORDER BY pa.CommentCount DESC, pa.AnswerCount DESC, pa.Upvotes DESC) AS OverallRank
    FROM 
        PostAnalysis pa
)
SELECT 
    r.PostId,
    r.Title,
    r.Tags,
    r.CommentCount,
    r.AnswerCount,
    r.LastVoteDate,
    r.Upvotes,
    r.Downvotes,
    r.CloseReopenCount,
    r.OwnerRank,
    r.OverallRank,
    CASE 
        WHEN r.OverallRank <= 10 THEN 'Top Post'
        WHEN r.OwnerRank <= 5 THEN 'Top Contributor'
        ELSE 'Regular Post'
    END AS PostCategory
FROM 
    RankedPosts r
WHERE 
    r.OverallRank <= 100
ORDER BY 
    r.OverallRank;

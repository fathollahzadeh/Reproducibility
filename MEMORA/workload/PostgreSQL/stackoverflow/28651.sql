WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        COALESCE(v.upvote_count, 0) AS UpVotes,
        COALESCE(v.downvote_count, 0) AS DownVotes,
        COALESCE(c.comment_count, 0) AS CommentCount,
        p.CreationDate,
        ROW_NUMBER() OVER (
            PARTITION BY p.PostTypeId 
            ORDER BY COALESCE(v.upvote_count, 0) DESC, p.CreationDate DESC
        ) AS Rank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS upvote_count,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS downvote_count
        FROM 
            Votes
        GROUP BY 
            PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS comment_count
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate BETWEEN '2023-01-01' AND '2023-12-31' 
)
SELECT 
    rp.PostId,
    rp.Title, 
    rp.Body,
    rp.UpVotes,
    rp.DownVotes,
    rp.CommentCount,
    CASE 
        WHEN rp.Rank <= 5 THEN 'Top 5 Questions This Year' 
        ELSE 'Other Questions' 
    END as RankCategory
FROM 
    RankedPosts rp
WHERE 
    rp.Rank <= 10
ORDER BY 
    RankCategory DESC, 
    rp.UpVotes DESC;

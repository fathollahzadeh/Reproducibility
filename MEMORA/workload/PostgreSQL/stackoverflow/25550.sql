
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(a.Id) DESC) AS Rank,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS NewestPosts
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.AnswerCount,
    rp.UpVotes,
    rp.DownVotes,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top 10 Questions'
        ELSE 'Other Questions'
    END AS Category,
    rp.NewestPosts
FROM 
    RankedPosts rp
WHERE 
    rp.NewestPosts <= 50 
ORDER BY 
    rp.Rank ASC, rp.PostId DESC;

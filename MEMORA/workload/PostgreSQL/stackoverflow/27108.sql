
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        COALESCE(NULLIF(ARRAY_AGG(v.VoteTypeId) FILTER (WHERE v.VoteTypeId = 2), '{}'), ARRAY[0]) AS UpvoteTypes,
        COALESCE(NULLIF(ARRAY_AGG(v.VoteTypeId) FILTER (WHERE v.VoteTypeId = 3), '{}'), ARRAY[0]) AS DownvoteTypes,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS ViewRank,
        ROW_NUMBER() OVER (ORDER BY p.AnswerCount DESC) AS AnswerRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        rp.UpvoteTypes,
        rp.DownvoteTypes,
        rp.ViewRank,
        rp.AnswerRank,
        (p.Body LIKE '%string%' OR p.Title LIKE '%string%') AS ContainsString
    FROM 
        RankedPosts rp
    JOIN 
        Posts p ON rp.PostId = p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.AnswerCount,
    tp.ViewRank,
    tp.AnswerRank,
    tp.ContainsString,
    CASE 
        WHEN tp.ContainsString THEN 'Yes'
        ELSE 'No'
    END AS StringMatched
FROM 
    TopPosts tp
WHERE 
    tp.ViewRank <= 10 OR tp.AnswerRank <= 10
ORDER BY 
    tp.ViewRank,
    tp.AnswerRank;

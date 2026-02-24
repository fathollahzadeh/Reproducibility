
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Body, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Body,
        rp.OwnerDisplayName,
        rp.AnswerCount,
        rp.UpVotesCount,
        rp.DownVotesCount,
        CAST(rp.UpVotesCount AS FLOAT) / NULLIF(rp.UpVotesCount + rp.DownVotesCount, 0) AS UpVoteRatio
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1 
)
SELECT 
    fp.PostId,
    fp.Title, 
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.AnswerCount,
    fp.UpVotesCount,
    fp.DownVotesCount,
    fp.UpVoteRatio,
    CASE 
        WHEN fp.UpVoteRatio > 0.7 THEN 'Highly Upvoted'
        WHEN fp.UpVoteRatio BETWEEN 0.5 AND 0.7 THEN 'Moderately Upvoted'
        ELSE 'Low Upvotes'
    END AS VoteCategory
FROM 
    FilteredPosts fp
ORDER BY 
    fp.UpVoteRatio DESC, 
    fp.CreationDate DESC
LIMIT 20;

WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY array_to_string(string_to_array(p.Tags, '><'), ',') ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '30 days') 
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        *,
        CONCAT('Answers: ', AnswerCount, ', Votes: ', UpVotes - DownVotes) AS Summary
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 
)
SELECT  
    fp.PostId,
    fp.Title,
    fp.Tags,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.Summary
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Tags, fp.CreationDate DESC;
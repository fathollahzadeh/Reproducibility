
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(a.Id) DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerName,
        rp.AnswerCount,
        rp.UpVotes - rp.DownVotes AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY rp.AnswerCount DESC, rp.UpVotes - rp.DownVotes DESC) AS Ranking
    FROM 
        RankedPosts rp
    WHERE 
        rp.OwnerPostRank = 1 
)
SELECT 
    tp.Title,
    tp.OwnerName,
    tp.AnswerCount,
    tp.NetVotes,
    tp.CreationDate,
    STRING_AGG(DISTINCT tc.TagName, ', ') AS Tags 
FROM 
    TopPosts tp
LEFT JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    LATERAL (SELECT unnest(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS TagName) AS tc ON TRUE
WHERE 
    tp.Ranking <= 10 
GROUP BY 
    tp.Title, tp.OwnerName, tp.AnswerCount, tp.NetVotes, tp.CreationDate
ORDER BY 
    tp.AnswerCount DESC;

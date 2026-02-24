
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(DISTINCT a.Id) DESC) AS OwnerRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.OwnerUserId, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.*,
        (UpVotes - DownVotes) AS NetVotes
    FROM 
        RankedPosts rp
    WHERE 
        OwnerRank = 1
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.OwnerDisplayName,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.NetVotes
FROM 
    TopPosts tp
WHERE 
    tp.NetVotes > 10 
ORDER BY 
    tp.NetVotes DESC, 
    tp.AnswerCount DESC;

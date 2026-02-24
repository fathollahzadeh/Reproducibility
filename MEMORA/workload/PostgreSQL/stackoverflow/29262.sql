WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= '2020-01-01' 
),
TopQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.LastActivityDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 5 
),
CommentsAndVotes AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Comments c
    LEFT JOIN 
        Votes v ON c.PostId = v.PostId
    GROUP BY 
        c.PostId
)
SELECT 
    tq.Title,
    tq.Body,
    tq.CreationDate,
    tq.LastActivityDate,
    tq.ViewCount,
    tq.Score,
    tq.OwnerDisplayName,
    COALESCE(cav.CommentCount, 0) AS CommentCount,
    COALESCE(cav.UpVotes, 0) AS UpVotes,
    COALESCE(cav.DownVotes, 0) AS DownVotes
FROM 
    TopQuestions tq
LEFT JOIN 
    CommentsAndVotes cav ON tq.PostId = cav.PostId
ORDER BY 
    tq.ViewCount DESC, tq.Score DESC;
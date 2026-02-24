
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(DISTINCT a.Id) DESC) AS RankByAnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName
), RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.Body,
    r.Tags,
    r.CreationDate,
    r.OwnerName,
    r.AnswerCount,
    r.UpVotes,
    r.DownVotes,
    ra.CommentCount,
    ra.LastEditDate,
    CASE WHEN ra.LastEditDate IS NOT NULL THEN 'Edited' ELSE 'Not Edited' END AS EditStatus,
    r.RankByAnswerCount
FROM 
    RankedPosts r
JOIN 
    RecentActivity ra ON r.PostId = ra.PostId
WHERE 
    r.RankByAnswerCount <= 10
ORDER BY 
    r.RankByAnswerCount;

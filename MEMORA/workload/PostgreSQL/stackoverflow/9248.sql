
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        COUNT(a.Id) AS AnswerCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC) AS ActivityRank
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
        p.Id, p.Title, p.CreationDate, u.DisplayName, p.LastActivityDate
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        OwnerName,
        AnswerCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        ActivityRank = 1
    ORDER BY 
        UpVotes - DownVotes DESC, AnswerCount DESC
    LIMIT 10
)
SELECT 
    tp.Title,
    tp.OwnerName,
    tp.CreationDate,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    COALESCE(b.Name, 'No Badge') AS UserBadge
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON tp.OwnerName = (SELECT DisplayName FROM Users WHERE Id = b.UserId)
ORDER BY 
    tp.CreationDate DESC;


WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId 
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, u.DisplayName, p.OwnerUserId, p.CreationDate
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    JOIN 
        Posts p ON p.Id = v.PostId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) >= 5 
),
PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.AnswerCount,
        mau.DisplayName AS MostActiveUser,
        mau.TotalUpVotes,
        mau.TotalDownVotes,
        mau.PostsCount
    FROM 
        RankedPosts rp
    JOIN 
        MostActiveUsers mau ON rp.OwnerPostRank <= 3 
    ORDER BY 
        rp.CommentCount DESC, 
        rp.AnswerCount DESC
)
SELECT 
    PostId,
    Title,
    OwnerDisplayName,
    CommentCount,
    AnswerCount,
    MostActiveUser,
    TotalUpVotes,
    TotalDownVotes,
    PostsCount
FROM 
    PostStats
WHERE 
    AnswerCount > 0 
ORDER BY 
    TotalUpVotes DESC, 
    CommentCount DESC;

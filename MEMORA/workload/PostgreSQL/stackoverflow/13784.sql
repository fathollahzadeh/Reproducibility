
WITH PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title AS PostTitle,
        p.CreationDate AS PostCreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        u.Reputation AS UserReputation,
        u.DisplayName AS UserDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, u.Id, u.Reputation, u.DisplayName
)
SELECT 
    PostId,
    PostTitle,
    PostCreationDate,
    CommentCount,
    VoteCount,
    UpVoteCount,
    DownVoteCount,
    BadgeCount,
    UserReputation,
    UserDisplayName
FROM 
    PostEngagement
ORDER BY 
    VoteCount DESC, CommentCount DESC;

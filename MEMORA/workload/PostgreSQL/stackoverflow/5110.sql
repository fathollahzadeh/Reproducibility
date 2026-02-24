
WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, 
        u.DisplayName
), 
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(ph.RevisionCount, 0) AS EditCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(b.BadgeCount, 0) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS RevisionCount
        FROM 
            PostHistory
        GROUP BY 
            PostId
    ) ph ON p.Id = ph.PostId
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            UserId,
            COUNT(*) AS BadgeCount
        FROM 
            Badges
        GROUP BY 
            UserId
    ) b ON p.OwnerUserId = b.UserId
),
FinalStats AS (
    SELECT 
        p.PostId,
        p.Title,
        p.ViewCount,
        p.EditCount,
        p.CommentCount,
        p.BadgeCount,
        u.TotalUpVotes,
        u.TotalDownVotes,
        u.TotalVotes
    FROM 
        PostStats p
    JOIN 
        UserVoteStats u ON p.BadgeCount >= 1
    WHERE 
        p.ViewCount > 1000
)
SELECT 
    PostId, 
    Title, 
    ViewCount, 
    EditCount, 
    CommentCount,
    BadgeCount, 
    TotalUpVotes, 
    TotalDownVotes, 
    TotalVotes
FROM 
    FinalStats
ORDER BY 
    ViewCount DESC, 
    TotalUpVotes DESC
LIMIT 10;

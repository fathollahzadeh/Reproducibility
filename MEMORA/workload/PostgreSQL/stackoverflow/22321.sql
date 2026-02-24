WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts 
        WHERE 
            PostTypeId = 2 
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments 
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(CASE WHEN vt.Name = 'AcceptedByOriginator' THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.UserId
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN pht.Name LIKE 'Edit%' THEN ph.CreationDate END) AS LastEdited,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS ClosedDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    COALESCE(uv.TotalUpVotes, 0) AS UserTotalUpVotes,
    COALESCE(uv.TotalDownVotes, 0) AS UserTotalDownVotes,
    COALESCE(uv.AcceptedAnswers, 0) AS UserAcceptedAnswers,
    ph.LastEdited,
    ph.ClosedDate,
    CASE 
        WHEN ph.ClosedDate IS NOT NULL THEN 'Closed'
        WHEN rp.AnswerCount > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS PostStatus,
    CASE WHEN rp.ViewCount > 1000 THEN 'High Visibility' ELSE 'Normal Visibility' END AS Visibility
FROM 
    RecentPosts rp
LEFT JOIN 
    UserVoteStats uv ON rp.OwnerUserId = uv.UserId
LEFT JOIN 
    PostHistoryInfo ph ON rp.PostId = ph.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.ViewCount DESC, 
    rp.CreationDate DESC
LIMIT 50;
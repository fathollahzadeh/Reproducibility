
WITH UserVoteSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS ClosedDate,
        STRING_AGG(DISTINCT ct.Name, ', ') AS CloseReasons
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    LEFT JOIN 
        CloseReasonTypes ct ON CAST(ph.Comment AS INTEGER) = ct.Id
    WHERE 
        p.PostTypeId = 1 AND ph.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, ph.CreationDate
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (ORDER BY COALESCE(c.CommentCount, 0) DESC) AS PopularityRank
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT ParentId AS PostId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) a ON p.Id = a.PostId
    WHERE 
        p.PostTypeId = 1
)
SELECT 
    p.Title,
    u.DisplayName AS User,
    p.ViewCount,
    pe.CommentCount,
    pe.AnswerCount,
    COALESCE(ub.TotalVotes, 0) AS UserTotalVotes,
    COALESCE(ub.UpVotes, 0) AS UserUpVotes,
    COALESCE(ub.DownVotes, 0) AS UserDownVotes,
    cp.ClosedDate,
    cp.CloseReasons
FROM 
    Posts p
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserVoteSummary ub ON u.Id = ub.UserId
LEFT JOIN 
    PostEngagement pe ON p.Id = pe.PostId
LEFT JOIN 
    ClosedPosts cp ON p.Id = cp.PostId
WHERE 
    p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months'
ORDER BY 
    p.ViewCount DESC, pe.PopularityRank
LIMIT 50;

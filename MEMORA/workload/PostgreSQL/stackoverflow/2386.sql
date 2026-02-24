
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(NULLIF(p.AcceptedAnswerId, -1), NULL) AS AcceptedAnswer,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
        AND p.Title IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),

PostStats AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.VoteCount,
        ru.TotalScore AS UserTotalScore
    FROM 
        RecentPosts rp
    JOIN 
        Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    JOIN 
        TopUsers ru ON ru.Id = u.Id
    WHERE 
        (rp.Score + COALESCE(rp.UpVoteCount, 0) - COALESCE(rp.DownVoteCount, 0)) > 0
)

SELECT 
    ps.Title,
    ps.PostId,
    ps.CreationDate,
    ps.CommentCount,
    ps.VoteCount,
    ps.UserTotalScore,
    RANK() OVER (ORDER BY ps.VoteCount DESC) AS RankByVotes,
    DENSE_RANK() OVER (ORDER BY ps.UserTotalScore DESC) AS RankByUserScore
FROM 
    PostStats ps
ORDER BY 
    ps.UserTotalScore DESC, ps.VoteCount DESC
LIMIT 10;

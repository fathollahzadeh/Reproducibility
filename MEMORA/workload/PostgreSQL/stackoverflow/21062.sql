
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.PostTypeId,
        COALESCE(SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN vt.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId AND vt.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND (p.Body IS NOT NULL AND p.Body != '')
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName, p.PostTypeId
),

RankedPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        OwnerDisplayName,
        UpVotes,
        DownVotes,
        CommentCount,
        RANK() OVER (PARTITION BY PostTypeId ORDER BY Score DESC, CreationDate DESC) AS ScoreRank
    FROM 
        RecentPosts
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        Score,
        CreationDate,
        OwnerDisplayName,
        UpVotes,
        DownVotes,
        CommentCount
    FROM 
        RankedPosts
    WHERE 
        ScoreRank <= 5
),

UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        AVG(p.Score) AS AveragePostScore,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS QuestionCount,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS AnswerCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.OwnerDisplayName AS TopPostOwner,
    tp.Title AS TopPostTitle,
    tp.Score AS TopPostScore,
    tp.CommentCount AS TopPostComments,
    us.DisplayName AS UserDisplayName,
    us.GoldBadges,
    us.AveragePostScore,
    us.QuestionCount,
    us.AnswerCount
FROM 
    TopPosts tp
JOIN 
    RecentPosts rp ON tp.PostId = rp.PostId
JOIN 
    UserStats us ON rp.OwnerDisplayName = us.DisplayName
WHERE 
    EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2
        GROUP BY v.PostId
        HAVING COUNT(v.Id) >= 10
    )
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;

WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        MAX(p.Score) AS MaxScore,
        MIN(p.CreationDate) AS FirstActivityDate,
        MAX(p.LastActivityDate) AS LastActivityDate
    FROM 
        Posts p
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.AnswerCount, p.CommentCount
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        us.DisplayName,
        us.PostCount,
        us.TotalScore,
        ROW_NUMBER() OVER (ORDER BY ps.MaxScore DESC) AS Rank
    FROM 
        PostStats ps
    JOIN 
        UserStats us ON ps.PostId = us.UserId
)
SELECT 
    tp.Rank,
    tp.Title,
    tp.DisplayName,
    tp.PostCount,
    tp.TotalScore
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Rank;
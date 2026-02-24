
WITH Post_Scores AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId, p.PostTypeId
),
Ranked_Posts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.Score,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        RANK() OVER (ORDER BY ps.Score + ps.UpVotes - ps.DownVotes DESC) AS PostRank
    FROM 
        Post_Scores ps
),
Top_Posts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.UpVotes,
        rp.DownVotes,
        rp.CommentCount
    FROM 
        Ranked_Posts rp
    WHERE 
        rp.PostRank <= 10
),
User_Scores AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    GROUP BY 
        u.Id, u.DisplayName
),
Top_Users AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.TotalScore,
        us.PostCount,
        ROW_NUMBER() OVER (ORDER BY us.TotalScore DESC) AS UserRank
    FROM 
        User_Scores us
    WHERE 
        us.PostCount > 0
)
SELECT 
    tp.Title AS TopPostTitle,
    tp.Score AS TopPostScore,
    tu.DisplayName AS TopUserName,
    tu.TotalScore AS UserTotalScore,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    tp.PostId,
    (SELECT 
         COUNT(*) 
     FROM 
         Comments c 
     WHERE 
         c.PostId = tp.PostId) AS TotalComments,
    CASE 
        WHEN tp.CommentCount > 0 THEN 'Comments Available'
        ELSE 'No Comments'
    END AS CommentsStatus
FROM 
    Top_Posts tp
JOIN 
    Top_Users tu ON tp.UpVotes > 5
ORDER BY 
    tp.Score DESC, tu.TotalScore DESC;

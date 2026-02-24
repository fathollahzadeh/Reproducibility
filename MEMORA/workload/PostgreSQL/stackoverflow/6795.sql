WITH PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(a.AcceptedAnswerCount) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN (
        SELECT 
            OwnerUserId,
            COUNT(*) AS AcceptedAnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2 AND AcceptedAnswerId IS NOT NULL
        GROUP BY 
            OwnerUserId
    ) a ON u.Id = a.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.DisplayName
),
CombinedData AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.CreationDate,
        pp.Score,
        pp.ViewCount,
        pp.CommentCount,
        pp.VoteCount,
        tu.UserId,
        tu.DisplayName AS UserDisplayName,
        tu.TotalBounties,
        tu.PostsCreated,
        tu.AcceptedAnswers
    FROM 
        PopularPosts pp
    JOIN 
        TopUsers tu ON pp.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE OwnerUserId = tu.UserId)
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.CreationDate,
    cd.Score,
    cd.ViewCount,
    cd.CommentCount,
    cd.VoteCount,
    cd.UserDisplayName,
    cd.TotalBounties,
    cd.PostsCreated,
    cd.AcceptedAnswers
FROM 
    CombinedData cd
ORDER BY 
    cd.Score DESC, cd.ViewCount DESC
LIMIT 50;
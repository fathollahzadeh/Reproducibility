
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    INNER JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5
),
CommentedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        h.PostId,
        h.CreationDate,
        h.Comment
    FROM 
        PostHistory h
    JOIN 
        PostHistoryTypes ht ON h.PostHistoryTypeId = ht.Id
    WHERE 
        ht.Name = 'Post Closed'
),
PostsWithLinkCounts AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS LinkCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
),
FinalOutput AS (
    SELECT 
        tu.DisplayName,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        COALESCE(cp.CommentCount, 0) AS CommentCount,
        COALESCE(lp.LinkCount, 0) AS LinkCount,
        COALESCE(cp.CommentCount, 0) + COALESCE(lp.LinkCount, 0) AS InteractionScore,
        CASE WHEN cl.PostId IS NOT NULL THEN TRUE ELSE FALSE END AS IsClosed
    FROM 
        RankedPosts rp
    INNER JOIN 
        TopUsers tu ON rp.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = tu.UserId)
    LEFT JOIN 
        CommentedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        PostsWithLinkCounts lp ON rp.PostId = lp.PostId
    LEFT JOIN 
        ClosedPosts cl ON rp.PostId = cl.PostId
    WHERE 
        rp.UserRank <= 3 
)
SELECT 
    DisplayName,
    COUNT(PostId) AS PostCount,
    SUM(ViewCount) AS TotalViews,
    AVG(InteractionScore) AS AverageInteractionScore,
    SUM(CASE WHEN IsClosed THEN 1 ELSE 0 END) AS ClosedPostCount
FROM 
    FinalOutput
GROUP BY 
    DisplayName
ORDER BY 
    TotalViews DESC, PostCount ASC;


WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        SUM(COALESCE(NULLIF(p.ViewCount, 0), 0)) AS TotalViews,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(DISTINCT p.Id) DESC) AS rn
    FROM
        Users u
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
TopUsers AS (
    SELECT
        UserId, DisplayName, Reputation, PostCount, PositivePosts, NegativePosts, TotalViews
    FROM
        UserStats
    WHERE
        rn = 1
    ORDER BY
        Reputation DESC
    LIMIT 10
),
PostLinksAggregate AS (
    SELECT
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount,
        STRING_AGG(DISTINCT pt.Name, ', ' ORDER BY pt.Name) AS LinkTypeNames
    FROM
        PostLinks pl
    JOIN
        LinkTypes lt ON pl.LinkTypeId = lt.Id
    JOIN
        Posts p ON pl.PostId = p.Id
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY
        pl.PostId
)
SELECT
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.PositivePosts,
    u.NegativePosts,
    u.TotalViews,
    p.Id AS PostId,
    p.Title,
    p.ViewCount,
    COALESCE(link.RelatedPostCount, 0) AS RelatedPostCount,
    COALESCE(link.LinkTypeNames, 'None') AS LinkTypeNames
FROM
    TopUsers u
JOIN
    Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN
    PostLinksAggregate link ON p.Id = link.PostId
WHERE
    p.CreationDate = (
        SELECT MAX(CreationDate)
        FROM Posts
        WHERE OwnerUserId = u.UserId
    )
ORDER BY
    u.Reputation DESC, p.ViewCount DESC;

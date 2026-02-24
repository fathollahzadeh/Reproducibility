
WITH RECURSIVE PostHierarchy AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.AcceptedAnswerId,
        p.ParentId,
        0 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 

    UNION ALL

    SELECT
        a.Id AS PostId,
        a.Title,
        a.AcceptedAnswerId,
        a.ParentId,
        ph.Level + 1 AS Level
    FROM
        Posts a
    INNER JOIN
        PostHierarchy ph ON a.ParentId = ph.PostId
    WHERE
        a.PostTypeId = 2 
),
PostStats AS (
    SELECT
        p.Id,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    LEFT JOIN
        Badges b ON p.OwnerUserId = b.UserId
    GROUP BY
        p.Id, p.Title, p.ViewCount
),
ClosedPosts AS (
    SELECT
        ph.PostId,
        p.Title,
        ph.Level,
        p.CreationDate
    FROM
        PostHierarchy ph
    JOIN
        Posts p ON ph.PostId = p.Id
    WHERE
        p.ClosedDate IS NOT NULL
),
TopPosts AS (
    SELECT
        ps.Id,
        ps.Title,
        ps.CommentCount,
        ps.TotalBountyAmount,
        ps.ViewCount,
        COALESCE(cp.PostId, 0) AS ClosedPostId
    FROM
        PostStats ps
    LEFT JOIN
        ClosedPosts cp ON ps.Id = cp.PostId
    ORDER BY
        ps.ViewCount DESC, ps.CommentCount DESC
    LIMIT 10
)

SELECT
    tp.Title AS PostTitle,
    tp.CommentCount,
    tp.TotalBountyAmount,
    CASE
        WHEN tp.ClosedPostId IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM
    TopPosts tp
ORDER BY
    tp.TotalBountyAmount DESC;

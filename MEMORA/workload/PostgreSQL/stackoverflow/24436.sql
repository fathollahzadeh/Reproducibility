WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        rp.TotalUpVotes,
        rp.TotalDownVotes
    FROM
        RankedPosts rp
    WHERE
        rp.RankByViews <= 5
),
PostWithBadges AS (
    SELECT
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        bp.Class AS BadgeClass
    FROM
        TopPosts tp
        LEFT JOIN Badges bp ON bp.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
),
FinalResults AS (
    SELECT
        p.Title,
        p.ViewCount,
        p.CommentCount,
        COALESCE(b.BadgeClass, 0) AS BadgeClass,
        (p.TotalUpVotes - p.TotalDownVotes) AS NetVotes,
        CASE 
            WHEN p.ViewCount IS NULL THEN 'No Views'
            WHEN p.ViewCount < 100 THEN 'Low Traffic'
            WHEN p.ViewCount BETWEEN 100 AND 1000 THEN 'Moderate Traffic'
            ELSE 'High Traffic'
        END AS TrafficLevel
    FROM
        TopPosts p
    LEFT JOIN PostWithBadges b ON p.PostId = b.PostId
)
SELECT
    Title,
    ViewCount,
    CommentCount,
    BadgeClass,
    NetVotes,
    TrafficLevel
FROM
    FinalResults
WHERE
    (BadgeClass = 1 OR BadgeClass = 2)
    AND NetVotes > 0
ORDER BY
    ViewCount DESC
LIMIT 10;
WITH RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS Owner,
        COALESCE(pv.VoteCount, 0) AS VoteCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        CASE
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1
            ELSE 0
        END AS HasAcceptedAnswer
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS VoteCount
        FROM
            Votes
        WHERE
            VoteTypeId IN (2, 3)  
        GROUP BY
            PostId
    ) pv ON p.Id = pv.PostId
    LEFT JOIN (
        SELECT
            PostId,
            COUNT(*) AS CommentCount
        FROM
            Comments
        GROUP BY
            PostId
    ) c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostHistoryData AS (
    SELECT
        ph.PostId,
        pht.Name AS ChangeType,
        COUNT(*) AS ChangeCount
    FROM
        PostHistory ph
    JOIN
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY
        ph.PostId, pht.Name
),
CombinedData AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Owner,
        rp.VoteCount,
        rp.CommentCount,
        rp.HasAcceptedAnswer,
        COALESCE(ph.ChangeCount, 0) AS ChangeCount
    FROM
        RecentPosts rp
    LEFT JOIN
        PostHistoryData ph ON rp.PostId = ph.PostId
),
RankedPosts AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY VoteCount DESC, CommentCount DESC, CreationDate DESC) AS Rank
    FROM
        CombinedData
    WHERE
        HasAcceptedAnswer = 1 OR ChangeCount > 0
)
SELECT
    Title,
    Owner,
    VoteCount,
    CommentCount,
    ChangeCount,
    Rank
FROM
    RankedPosts
WHERE
    Rank <= 10
ORDER BY
    Rank;
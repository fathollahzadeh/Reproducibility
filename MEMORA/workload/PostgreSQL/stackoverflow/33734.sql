WITH RecursiveCTE AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(PH.UserId, 0) AS LastEditedUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM
        Posts p
    LEFT JOIN
        PostHistory PH ON p.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6) 
    WHERE
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),

MostActiveUsers AS (
    SELECT
        u.Id,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Users u
    JOIN
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        u.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '2 years'
    GROUP BY
        u.Id, u.DisplayName
    HAVING
        COUNT(DISTINCT p.Id) > 5
),

ClosedPosts AS (
    SELECT
        p.Id AS ClosedPostId,
        PH.UserDisplayName AS ClosedBy,
        PH.CreationDate AS CloseDate,
        PH.Comment AS CloseReason
    FROM
        Posts p
    JOIN
        PostHistory PH ON p.Id = PH.PostId AND PH.PostHistoryTypeId = 10 
    WHERE
        PH.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
)

SELECT
    RCTE.PostId,
    RCTE.Title,
    RCTE.CreationDate,
    RCTE.LastEditedUserId,
    AU.DisplayName AS ActiveUserName,
    AU.PostCount AS ActiveUserPostCount,
    AU.UpVotes,
    AU.DownVotes,
    CP.ClosedPostId,
    CP.ClosedBy,
    CP.CloseDate,
    CP.CloseReason
FROM
    RecursiveCTE RCTE
LEFT JOIN
    MostActiveUsers AU ON RCTE.LastEditedUserId = AU.Id
LEFT JOIN
    ClosedPosts CP ON RCTE.PostId = CP.ClosedPostId
WHERE
    RCTE.OwnerPostRank <= 10 
ORDER BY
    RCTE.CreationDate DESC, AU.PostCount DESC NULLS LAST;
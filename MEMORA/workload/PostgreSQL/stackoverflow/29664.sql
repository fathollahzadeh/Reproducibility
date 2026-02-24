WITH FilteredPosts AS (
    SELECT
        p.Id AS PostID,
        p.Title,
        p.ViewCount,
        p.Tags,
        STRING_AGG(t.TagName, ', ') AS TagList,
        U.DisplayName AS OwnerDisplayName
    FROM
        Posts p
    JOIN
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Tags t ON t.WikiPostId = p.Id OR t.ExcerptPostId = p.Id
    WHERE
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 MONTH'
        AND p.PostTypeId IN (1, 2)  
    GROUP BY
        p.Id, p.Title, p.ViewCount, p.Tags, U.DisplayName
),
PostScore AS (
    SELECT
        PostID,
        Title,
        ViewCount,
        TagList,
        OwnerDisplayName,
        RANK() OVER (ORDER BY ViewCount DESC) AS ViewRank
    FROM
        FilteredPosts
),
ClosedPostHistory AS (
    SELECT
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName AS ClosedBy,
        c.Name AS CloseReason
    FROM
        PostHistory ph
    JOIN
        CloseReasonTypes c ON ph.Comment::int = c.Id
    WHERE
        ph.PostHistoryTypeId = 10  
)
SELECT 
    ps.PostID, 
    ps.Title, 
    ps.ViewCount, 
    ps.TagList, 
    ps.OwnerDisplayName, 
    ps.ViewRank,
    COALESCE(cph.ClosedBy, 'Not Closed') AS ClosedBy,
    COALESCE(cph.CloseReason, 'N/A') AS CloseReason
FROM 
    PostScore ps
LEFT JOIN 
    ClosedPostHistory cph ON ps.PostID = cph.PostId
ORDER BY 
    ps.ViewRank;

WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount,
        COUNT(DISTINCT v.PostId) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
), 
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes, 
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS HasAcceptedAnswer,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS HistoryCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        RANK() OVER (ORDER BY COUNT(DISTINCT c.Id) DESC) AS PopularityRank
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.OwnerUserId, p.Title, p.CreationDate
),
TagsWithPostCount AS (
    SELECT 
        t.Id AS TagId, 
        t.TagName, 
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.Id, t.TagName
),
ClosedPostReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment = CAST(cr.Id AS VARCHAR)
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    ud.UserId,
    ud.UpVotesCount,
    ud.DownVotesCount,
    pd.Title,
    pd.CreationDate,
    pd.HasAcceptedAnswer,
    pd.CommentCount,
    tp.TagName,
    tp.PostCount,
    cpr.CloseReasons
FROM 
    UserVoteCounts ud
JOIN 
    PostDetails pd ON pd.OwnerUserId = ud.UserId
LEFT JOIN 
    TagsWithPostCount tp ON tp.PostCount > 2 
LEFT JOIN 
    ClosedPostReasons cpr ON cpr.PostId = pd.PostId
WHERE 
    ud.UpVotesCount > ud.DownVotesCount
AND 
    pd.PopularityRank <= 5 
ORDER BY 
    ud.UserId, pd.CreationDate DESC;

WITH NumberOfVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountySpent,
        COUNT(DISTINCT p.Id) AS TotalQuestionsAsked
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedPostHistory AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS CloseVoteCount,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasonNames
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        php.CloseVoteCount,
        php.CloseReasonNames,
        nv.TotalVotes,
        nv.UpVotes,
        nv.DownVotes,
        au.TotalQuestionsAsked,
        au.TotalBountySpent
    FROM 
        Posts p
    LEFT JOIN 
        ClosedPostHistory php ON p.Id = php.PostId
    LEFT JOIN 
        NumberOfVotes nv ON p.Id = nv.PostId
    LEFT JOIN 
        ActiveUsers au ON p.OwnerUserId = au.UserId
)
SELECT 
    pd.PostId,
    pd.Title,
    COALESCE(pd.CloseVoteCount, 0) AS CloseVoteCount,
    COALESCE(pd.CloseReasonNames, 'No close reasons') AS CloseReasonNames,
    COALESCE(pd.TotalVotes, 0) AS TotalVotes,
    COALESCE(pd.UpVotes, 0) AS UpVotes,
    COALESCE(pd.DownVotes, 0) AS DownVotes,
    COALESCE(pd.TotalQuestionsAsked, 0) AS TotalQuestionsAsked,
    COALESCE(pd.TotalBountySpent, 0) AS TotalBountySpent,
    CASE 
        WHEN pd.DownVotes > pd.UpVotes THEN 'Needs Improvement'
        WHEN pd.CloseVoteCount > 5 THEN 'Potentially Problematic'
        WHEN pd.TotalVotes IS NULL THEN 'No Activity'
        ELSE 'Active Discussion'
    END AS PostActivityStatus,
    CASE 
        WHEN pd.CloseVoteCount > 5 AND pd.TotalVotes < 10 THEN 'Potential Mismanagement'
        ELSE 'Normal Activity'
    END AS ManagementStatus
FROM 
    PostDetails pd
WHERE 
    pd.UpVotes > 0 OR pd.DownVotes > 0
ORDER BY 
    pd.CloseVoteCount DESC,
    pd.TotalVotes DESC
FETCH FIRST 100 ROWS ONLY;
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
        AND p.ViewCount IS NOT NULL
),
UserVoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN v.UserId IS NOT NULL THEN 1 END) AS TotalVotes,
        COUNT(DISTINCT v.UserId) AS UniqueVoters
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 month')
    GROUP BY 
        v.PostId
),
PostLinksDetails AS (
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        lt.Name AS LinkType
    FROM 
        PostLinks pl
    LEFT JOIN 
        LinkTypes lt ON pl.LinkTypeId = lt.Id
),
OpenClosedPosts AS (
    SELECT 
        p.Id,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS Status
    FROM 
        Posts p
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.PostTypeId,
    rp.CreationDate,
    u.UpVotes,
    u.DownVotes,
    u.TotalVotes,
    u.UniqueVoters,
    pl.RelatedPostId,
    pl.LinkType,
    oc.Status,
    CASE 
        WHEN oc.Status = 'Closed' AND u.TotalVotes > 10 THEN 'Closed with many votes'
        WHEN oc.Status = 'Open' AND EXISTS (SELECT 1 FROM Comments c WHERE c.PostId = rp.PostId AND c.Score < 0) THEN 'Open with negative comments'
        ELSE 'Normal Status'
    END AS PostStatusComment
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVoteSummary u ON rp.PostId = u.PostId
LEFT JOIN 
    PostLinksDetails pl ON rp.PostId = pl.PostId
LEFT JOIN 
    OpenClosedPosts oc ON rp.PostId = oc.Id
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.PostRank, oc.Status DESC, u.TotalVotes DESC;